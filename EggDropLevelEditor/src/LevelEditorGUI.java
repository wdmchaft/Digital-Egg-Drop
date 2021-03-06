import java.awt.Container;

import javax.swing.JComboBox;
import javax.swing.JFrame;
import javax.swing.JList;
import javax.swing.JScrollPane;
import javax.swing.SwingUtilities;

public class LevelEditorGUI extends JFrame {

	/**
	 * 
	 */
	private static final long serialVersionUID = 141305690713560959L;
	final JList currentBlocksList;
	final JList blocksToAddList;
	final JList disastersList;
	
	final JScrollPane blocksScroll;
	final JScrollPane blocksToAddScroll;
	final JScrollPane disastersScroll;
	
	final LevelEditorView view;
	
	final JComboBox types;
	
	public LevelEditorGUI()
	{
		super("Egg Drop Level Editor");
		
		this.setDefaultCloseOperation(EXIT_ON_CLOSE);
		
		this.setBounds(0, 0, 1000, 600);
		
		//pure manual layout
		this.setLayout(null);
		
		Container cp = this.getContentPane();
		
		currentBlocksList = new JList();
		blocksToAddList = new JList();
		disastersList = new JList();
		
		blocksScroll = new JScrollPane(currentBlocksList);
		blocksScroll.setBounds(5, 5, 100, 540);
		
		cp.add(blocksScroll);
		
		blocksToAddScroll = new JScrollPane(blocksToAddList);
		blocksToAddScroll.setBounds(110, 5, 100, 540);
		
		cp.add(blocksToAddScroll);
		
		disastersScroll = new JScrollPane(disastersList);
		disastersScroll.setBounds(215, 5, 100, 540);
		
		cp.add(disastersScroll);
		
		view = new LevelEditorView(320, 110);
		cp.add(view);
	
		String[] options = {"Block", "Egg", "Nail", "Hinge", "Wind"};
		types = new JComboBox(options);
		types.setBounds(805, 5, 100, 25);
		cp.add(types);
		
	}
	
	public void saveLevel()
	{
		//open up a file chooser to choose the file to save. 
	}
	
	public static void main(String[] args)
	{
		SwingUtilities.invokeLater(new Runnable() {
			public void run()
			{
				new LevelEditorGUI().setVisible(true);
			}
		});
	}
	
}
